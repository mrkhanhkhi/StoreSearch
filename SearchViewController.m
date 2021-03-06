//
//  SearchViewController.m
//  StoreSearch
//
//  Created by Nguyen Duy Khanh on 3/18/16.
//  Copyright © 2016 Nguyen Duy Khanh. All rights reserved.
//

#import "SearchViewController.h"
#import "SearchResult.h"
#import "SearchResultCell.h"

static NSString * const SearchResultCellIdentifier = @"SearchResultCell";
static NSString * const NothingFoundCellIdentifier = @"NothingFoundCell";

@interface SearchViewController () <UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SearchViewController
{
    NSMutableArray *_searchResults;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    self.tableView.rowHeight = 80;
    
    UINib *cellNib = [UINib nibWithNibName:SearchResultCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:SearchResultCellIdentifier];
    
    cellNib = [UINib nibWithNibName:NothingFoundCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:NothingFoundCellIdentifier];
    
    [self.searchBar becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_searchResults == nil) {
        return 0;
    } else if ([_searchResults count] == 0) {
        return 1;
    } else {
        return [_searchResults count];
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([_searchResults count] == 0) {
        return [tableView dequeueReusableCellWithIdentifier:NothingFoundCellIdentifier forIndexPath:indexPath];
    } else {
        SearchResultCell *cell = (SearchResultCell *)[tableView dequeueReusableCellWithIdentifier:SearchResultCellIdentifier forIndexPath:indexPath];
        
        SearchResult *searchResult = _searchResults[indexPath.row];
        cell.nameLabel.text = searchResult.name;
        NSString *artistName = searchResult.artistName;
        
        if (artistName == nil) {
            artistName = @"Unknown";
        }
        
        NSString *kind = [self kindForDisplay:searchResult.kind];
        cell.artistNameLabel.text = [NSString stringWithFormat:@"%@ (%@)",artistName,kind];
        
    return cell;
    }
}


//Sửa tên display của từng loại
-(NSString*)kindForDisplay:(NSString*)kind
{
    if ([kind isEqualToString:@"album"]) {
        return @"Album";
    } else if ([kind isEqualToString:@"audiobook"]) {
        return @"Audio Book";
    } else if ([kind isEqualToString:@"book"]) {
        return @"Book";
    } else if ([kind isEqualToString:@"ebook"]) {
        return @"E-book";
    } else if ([kind isEqualToString:@"feature-movie"]) {
        return @"Movie";
    } else if ([kind isEqualToString:@"podcast"]){
        return @"Music Video";
    } else if ([kind isEqualToString:@"software"]){
        return @"App";
    } else if ([kind isEqualToString:@"song"]) {
        return @"Song";
    } else if ([kind isEqualToString:@"tv-episode"]){
        return @"TV Episode";
    } else {
        return kind;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_searchResults count] == 0) {
        return nil;
    } else {
        return indexPath;
    }
}

#pragma mark - UISearchBarDelegate
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if ([searchBar.text length] > 0) {
        [searchBar resignFirstResponder];
        _searchResults = [NSMutableArray arrayWithCapacity:10];
        
        NSURL *url = [self urlWithSearchText:searchBar.text];
        NSLog(@"URL '%@'",url);
        
        NSString *jsonString = [self performStoreRequestWithURL:url];
        
        if (jsonString == nil) {
            [self showNetWorkError];
            return;
        }
        
        NSDictionary *dictionary = [self parseJSON:jsonString];
        if (dictionary == nil) {
            [self showNetWorkError];
            return;
        }
        
        NSLog(@"Dictionary '%@'",dictionary);
        [self parseDictionary:dictionary];
        [_searchResults sortUsingSelector:@selector(compareName:)];
    }
    [self.tableView reloadData];
}

-(NSURL*)urlWithSearchText:(NSString*)searhText
{
    NSString *escapedSearchText = [searhText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/search?term=%@",searhText];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

-(NSString*)performStoreRequestWithURL:(NSString*)url
{
    NSError *error;
    
    //Trả vể một đối tượng string chứa dữ liệu từ server của đường link "url".
    NSString *resultString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (resultString == nil) {
        NSLog(@"Download Error: %@",error);
        return nil;
    }
    return resultString;
}

//Chuyển kết quả tìm kiếm từ dạng JSON thành NSDictionary
-(NSDictionary*)parseJSON:(NSString*)jsonString
{
    //Chuyển đổi sang đối tượng NSData
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    
    id resultObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    if (resultObject == nil) {
        NSLog(@"JSON Error: %@", error);
        return nil;
    }
    
    if (![resultObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"JSON Error: Expected dictionary");
        return nil;
    }
    return resultObject;
}

-(void)parseDictionary:(NSDictionary*)dictionary
{
    NSArray *array = dictionary[@"results"];
    if (array == nil) {
        NSLog(@"Expected 'result' array");
        return;
    }
    
    for (NSDictionary *resultDict in array) {
        
        SearchResult *searchResult;
        NSString *wrapperType = resultDict[@"wrapperType"];
        NSString *kind = resultDict[@"kind"];
        
        if ([wrapperType isEqualToString:@"track"]) {
            searchResult = [self parseTrack:resultDict];
        } else if ([wrapperType isEqualToString:@"audiobook"]) {
            searchResult = [self parseAudioBook:resultDict];
        } else if ([wrapperType isEqualToString:@"software"]){
            searchResult = [self parseSoftware:resultDict];
        } else if ([kind isEqualToString:@"ebook"]){
            searchResult = [self parseEBook:resultDict];
        }
        
        if (searchResult != nil) {
            [_searchResults addObject:searchResult];
        }
        NSLog(@"wrapperType: %@, kind:%@",resultDict[@"wrapperType"],resultDict[@"kind"]);
    }
}

//Parse dữ liệu track, hiển thị theo từng thuộc tính của data trên cell
-(SearchResult*)parseTrack:(NSDictionary*)dictionary
{
    SearchResult *searchResult = [[SearchResult alloc]init];
    searchResult.name = dictionary[@"trackName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"trackViewUrl"];
    searchResult.kind = dictionary[@"kind"];
    searchResult.price = dictionary[@"trackPrice"];
    searchResult.currency = dictionary[@"currency"];
    searchResult.genre = dictionary[@"primaryGenreName"];
    
    return searchResult;
    
}

-(SearchResult*)parseAudioBook:(NSDictionary*)dictionary
{
    SearchResult *searchResult = [[SearchResult alloc]init];
    searchResult.name = dictionary[@"collectionName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"collectionViewUrl"];
    searchResult.kind = @"audiobook";
    searchResult.price = dictionary[@"collectionPrice"];
    searchResult.currency = dictionary[@"currency"];
    searchResult.genre = dictionary[@"primaryGenreName"];
    
    return searchResult;
    
}

-(SearchResult*)parseSoftware:(NSDictionary*)dictionary
{
    SearchResult *searchResult = [[SearchResult alloc]init];
    searchResult.name = dictionary[@"trackName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"trackViewUrl"];
    searchResult.kind = dictionary[@"kind"];
    searchResult.price = dictionary[@"price"];
    searchResult.currency = dictionary[@"currency"];
    searchResult.genre = dictionary[@"primaryGenreName"];
    
    return searchResult;
    
}

-(SearchResult*)parseEBook:(NSDictionary*)dictionary
{
    SearchResult *searchResult = [[SearchResult alloc]init];
    searchResult.name = dictionary[@"trackName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"trackViewUrl"];
    searchResult.kind = dictionary[@"kind"];
    searchResult.price = dictionary[@"price"];
    searchResult.currency = dictionary[@"currency"];
    searchResult.genre = [(NSArray*)dictionary[@"genres"]componentsJoinedByString:@","];
    
    return searchResult;
    
}

-(void)showNetWorkError
{
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Whoops"
                                                       message:@"There was error reading from the iTunes Store. Please try again"
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
    [alertView show];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end


